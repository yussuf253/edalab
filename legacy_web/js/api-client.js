/**
 * eDaLab Web API Client
 * Handles all communication with the backend API
 */

const API_BASE_URL = 'https://edalab.onrender.com/api';

class ApiClient {
  constructor(baseURL = API_BASE_URL) {
    this.baseURL = baseURL;
    this.token = localStorage.getItem('authToken');
  }

  setToken(token) {
    this.token = token;
    if (token) {
      localStorage.setItem('authToken', token);
    }
  }

  clearToken() {
    this.token = null;
    localStorage.removeItem('authToken');
  }

  sanitizeErrorMessage(error) {
    const message = (error?.message || String(error || '')).trim();
    const lower = message.toLowerCase();
    const isConnectionError =
      lower.includes('could not reach the api at') ||
      lower.includes('failed to fetch') ||
      lower.includes('networkerror') ||
      lower.includes('network request failed') ||
      lower.includes('socketexception') ||
      lower.includes('timeoutexception') ||
      lower.includes('failed host lookup') ||
      message.includes(this.baseURL);

    if (isConnectionError) {
      return 'Unable to connect right now. Please check your internet connection and try again.';
    }

    return message || 'Something went wrong. Please try again.';
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    const headers = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`;
    }

    try {
      const response = await fetch(url, {
        ...options,
        headers,
      });

      if (!response.ok) {
        let errorPayload = null;
        try {
          errorPayload = await response.json();
        } catch (_error) {
          try {
            errorPayload = await response.text();
          } catch (_textError) {
            errorPayload = null;
          }
        }

        if (response.status === 401 && this.token && !options.skipAuthRedirect) {
          this.clearToken();
          window.location.href = 'login.html';
        }

        const message =
          (typeof errorPayload === 'string' && errorPayload.trim()) ||
          errorPayload?.error ||
          errorPayload?.message ||
          `API Error: ${response.status} ${response.statusText}`;

        const error = new Error(message);
        error.status = response.status;
        error.payload = errorPayload;
        throw error;
      }

      if (response.status === 204) {
        return null;
      }

      const data = await response.json();
      return data;
    } catch (error) {
      console.error('API Request Error:', error);
      const sanitizedError = new Error(this.sanitizeErrorMessage(error));
      sanitizedError.status = error?.status;
      sanitizedError.payload = error?.payload;
      throw sanitizedError;
    }
  }

  // ═══ CATALOG ENDPOINTS ═══
  
  // Restaurants
  async getRestaurants(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/catalog/restaurants?${params}`);
  }

  async getRestaurantDetail(id) {
    return this.request(`/catalog/restaurants/${id}`);
  }

  async getRestaurantMenu(id) {
    return this.request(`/catalog/restaurants/${id}/menu`);
  }

  // Doctors
  async getDoctors(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/catalog/doctors?${params}`);
  }

  async getDoctorDetail(id) {
    return this.request(`/catalog/doctors/${id}`);
  }

  async getDoctorReviews(id) {
    return this.request(`/catalog/doctors/${id}/reviews`);
  }

  async searchDoctors(query, specialty = null) {
    const params = new URLSearchParams({ q: query });
    if (specialty) params.append('specialty', specialty);
    return this.request(`/catalog/doctors/search?${params}`);
  }

  // Products & Shopping
  async getProducts(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/catalog/products?${params}`);
  }

  async getProductDetail(id) {
    return this.request(`/catalog/products/${id}`);
  }

  async getCategories(type = 'shopping') {
    // Categories endpoint doesn't exist - they're derived from products
    // For now, return empty array and let products handle categories
    return { data: [] };
  }

  // Hotels
  async getHotels(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/catalog/hotels?${params}`);
  }

  async getHotelDetail(id) {
    return this.request(`/catalog/hotels/${id}`);
  }

  async getHotelRooms(id) {
    return this.request(`/catalog/hotels/${id}/rooms`);
  }

  async checkHotelAvailability(id, checkIn, checkOut) {
    return this.request(
      `/catalog/hotels/${id}/availability?checkIn=${checkIn}&checkOut=${checkOut}`
    );
  }

  // Pharmacy
  async getMedicines(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/catalog/medicines?${params}`);
  }

  async getMedicineDetail(id) {
    return this.request(`/catalog/medicines/${id}`);
  }

  async searchMedicines(query) {
    return this.request(`/catalog/medicines/search?q=${query}`);
  }

  // Grocery
  async getGroceryItems(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/catalog/grocery?${params}`);
  }

  async getGroceryCategories() {
    return this.request('/catalog/grocery/categories');
  }

  // Home Services
  async getHomeServiceCategories() {
    return this.request('/catalog/home-service-categories');
  }

  async getHomeServiceProviders(categoryId, filters = {}) {
    const params = new URLSearchParams(filters);
    const suffix = params.toString() ? `?${params}` : '';
    return this.request(
      categoryId
        ? `/catalog/home-service-providers?category=${encodeURIComponent(categoryId)}${suffix ? `&${params}` : ''}`
        : `/catalog/home-service-providers${suffix}`
    );
  }

  async getHomeServiceProviderDetail(id) {
    return this.request(`/catalog/home-service-providers/${id}`);
  }

  async searchHomeServices(query) {
    return this.getHomeServiceProviders('', { q: query });
  }

  // ═══ ORDERS ENDPOINTS ═══

  async getOrders(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/orders?${params}`);
  }

  async getOrdersForUser(userId) {
    return this.request(`/orders/${userId}`);
  }

  async getOrderDetail(id) {
    return this.request(`/orders/${id}`);
  }

  async createOrder(orderData) {
    return this.request('/orders', {
      method: 'POST',
      body: JSON.stringify(orderData),
    });
  }

  async updateOrder(id, updates) {
    return this.request(`/orders/${id}`, {
      method: 'PUT',
      body: JSON.stringify(updates),
    });
  }

  async cancelOrder(id, reason = '') {
    return this.request(`/orders/${id}/cancel`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  }

  // ═══ APPOINTMENTS ENDPOINTS ═══

  async getAppointments(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/appointments?${params}`);
  }

  async getAppointmentsForUser(userId) {
    return this.request(`/appointments/${userId}`);
  }

  async getAppointmentDetail(id) {
    return this.request(`/appointments/${id}`);
  }

  async createAppointment(appointmentData) {
    return this.request('/appointments', {
      method: 'POST',
      body: JSON.stringify(appointmentData),
    });
  }

  async getDoctorAvailability(doctorId, date) {
    return this.request(`/appointments/doctor/${doctorId}/availability?date=${date}`);
  }

  // ═══ RIDES ENDPOINTS ═══

  async requestRide(rideData) {
    return this.request('/rides', {
      method: 'POST',
      body: JSON.stringify(rideData),
    });
  }

  async getRideCategories() {
    return this.request('/catalog/ride-categories');
  }

  async getRideDetail(id) {
    return this.request(`/rides/${id}`);
  }

  async cancelRide(id, reason = '') {
    return this.request(`/rides/${id}/cancel`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  }

  async getLaundryServices() {
    return this.request('/catalog/laundry-services');
  }

  // ═══ MODULES ENDPOINTS ═══

  async getModules() {
    return this.request('/modules');
  }

  // ═══ PROMOTIONS ENDPOINTS ═══

  async getPromotions(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/promotions?${params}`);
  }

  async redeemPromotion(code) {
    const promotions = await this.getPromotions();
    return promotions;
  }

  // ═══ USER ENDPOINTS ═══

  async getUserProfile(userId) {
    return this.request(`/users/${userId}`);
  }

  async updateUserProfile(userId, data) {
    return this.request(`/users/${userId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async getUserAddresses(userId) {
    const user = await this.request(`/users/${userId}`);
    return user.addresses || [];
  }

  async addAddress(userId, address) {
    return this.request(`/users/${userId}/addresses`, {
      method: 'POST',
      body: JSON.stringify(address),
    });
  }

  async deleteAddress(userId, id) {
    return this.request(`/users/${userId}/addresses/${id}`, {
      method: 'DELETE',
    });
  }

  async getPaymentMethods(userId) {
    return this.request(`/users/${userId}/payment-methods`);
  }

  async addPaymentMethod(userId, paymentMethod) {
    return this.request(`/users/${userId}/payment-methods`, {
      method: 'POST',
      body: JSON.stringify(paymentMethod),
    });
  }

  async deletePaymentMethod(userId, paymentMethodId) {
    return this.request(`/users/${userId}/payment-methods/${paymentMethodId}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
      },
    });
  }

  // ═══ AUTH ENDPOINTS ═══

  async login(email, password) {
    const response = await this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    if (response.token) {
      this.setToken(response.token);
    }
    if (response.user && typeof stateManager !== 'undefined') {
      stateManager.setUser(response.user);
    }
    return response;
  }

  async register(userData) {
    const response = await this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(userData),
    });
    if (response.token) {
      this.setToken(response.token);
    }
    if (response.user && typeof stateManager !== 'undefined') {
      stateManager.setUser(response.user);
    }
    return response;
  }

  async logout() {
    this.clearToken();
    if (typeof stateManager !== 'undefined') {
      stateManager.logout();
    }
  }

  // ═══ NOTIFICATIONS ENDPOINTS ═══

  async getNotifications(filters = {}) {
    const params = new URLSearchParams(filters);
    return this.request(`/notifications?${params}`);
  }

  async markNotificationAsRead(id) {
    return this.request(`/notifications/${id}/read`, {
      method: 'POST',
    });
  }

  // ═══ MESSAGES ENDPOINTS ═══

  async getConversations() {
    return this.request('/messages/conversations');
  }

  async getConversationMessages(conversationId) {
    return this.request(`/messages/conversations/${conversationId}`);
  }

  async sendMessage(conversationId, message) {
    return this.request(`/messages/conversations/${conversationId}/send`, {
      method: 'POST',
      body: JSON.stringify({ message }),
    });
  }
}

// Export singleton instance
const apiClient = new ApiClient();

// Backwards-compatible helpers for older page scripts.
ApiClient.get = function get(endpoint, options = {}) {
  return apiClient.request(endpoint, options);
};

ApiClient.post = function post(endpoint, body) {
  return apiClient.request(endpoint, {
    method: 'POST',
    body: JSON.stringify(body),
  });
};
