#!/bin/bash
# Pro App Modernization Script
# This script helps modernize multiple pro app screens at once

# Usage: ./modernize_pro_screens.sh

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Pro App Modernization Progress${NC}"
echo -e "${BLUE}=====================================${NC}\n"

# Completed screens
COMPLETED=(
  "lib/pro/features/auth/screens/pro_login_screen.dart"
  "lib/pro/features/auth/screens/pro_register_screen.dart"
  "lib/pro/features/auth/screens/pro_signup_screen.dart"
  "lib/pro/features/entry/screens/pro_welcome_screen.dart"
)

# Remaining screens by module
declare -A REMAINING_SCREENS

REMAINING_SCREENS[ENTRY]="
  lib/pro/features/entry/screens/pro_entry_screen.dart
  lib/pro/features/onboarding/screens/pro_onboarding_screen.dart
"

REMAINING_SCREENS[DELIVERY]="
  lib/pro/features/delivery/screens/delivery_dashboard_screen.dart
  lib/pro/features/delivery/screens/delivery_queue_screen.dart
"

REMAINING_SCREENS[RIDER]="
  lib/pro/features/rider/screens/rider_dashboard_screen.dart
  lib/pro/features/rider/screens/rider_queue_screen.dart
  lib/pro/features/rider/screens/rider_active_delivery_screen.dart
  lib/pro/features/rider/screens/rider_active_trip_screen.dart
"

REMAINING_SCREENS[DOCTOR]="
  lib/pro/features/doctor/screens/doctor_dashboard_screen.dart
  lib/pro/features/doctor/screens/doctor_appointments_queue_screen.dart
  lib/pro/features/doctor/screens/doctor_availability_screen.dart
  lib/pro/features/doctor/screens/doctor_schedule_settings_screen.dart
  lib/pro/features/doctor/screens/doctor_telemedicine_screen.dart
"

REMAINING_SCREENS[PROVIDER]="
  lib/pro/features/provider/screens/provider_availability_screen.dart
  lib/pro/features/provider/screens/provider_calendar_screen.dart
  lib/pro/features/provider/screens/provider_jobs_queue_screen.dart
  lib/pro/features/provider/screens/provider_schedule_settings_screen.dart
"

REMAINING_SCREENS[SHOP]="
  lib/pro/features/shop/screens/shop_catalog_screen.dart
  lib/pro/features/shop/screens/shop_orders_queue_screen.dart
  lib/pro/features/shop/screens/shop_product_create_screen.dart
  lib/pro/features/shop/screens/shop_products_screen.dart
  lib/pro/features/shop/screens/shop_store_setup_screen.dart
"

REMAINING_SCREENS[CORE_PRO]="
  lib/pro/features/dashboard/screens/pro_dashboard_screen.dart
  lib/pro/features/operations/screens/pro_operations_screen.dart
  lib/pro/features/messages/screens/pro_messages_screen.dart
  lib/pro/features/insights/screens/pro_insights_screen.dart
"

# Print completed
echo -e "${GREEN}✓ COMPLETED (4 screens)${NC}"
for screen in "${COMPLETED[@]}"; do
  echo "  ✓ $(basename "$screen")"
done

echo ""

# Print remaining by module
total_remaining=0
for module in "${!REMAINING_SCREENS[@]}"; do
  screens=("${REMAINING_SCREENS[$module]}")
  count=$(echo "$screens" | wc -w)
  total_remaining=$((total_remaining + count))
  
  echo -e "${YELLOW}○ $module (${count} screens)${NC}"
  echo "$screens" | xargs -n1 | while read screen; do
    [ ! -z "$screen" ] && echo "  ○ $(basename "$screen")"
  done
  echo ""
done

echo -e "${BLUE}=====================================${NC}"
echo -e "Total Remaining: ${YELLOW}$total_remaining screens${NC}"
echo -e "Total Completed: ${GREEN}4 screens${NC}"
echo -e "Total Progress: $(echo "scale=1; 4 * 100 / 33" | bc)%"
echo -e "${BLUE}=====================================${NC}\n"

# Verification
echo -e "${BLUE}Running Compilation Check...${NC}"
cd /Users/youssoufhassan/edalab_app

# Check completed screens
echo -e "\n${BLUE}Checking completed screens:${NC}"
for screen in "${COMPLETED[@]}"; do
  if flutter analyze "$screen" 2>&1 | grep -q "No issues found"; then
    echo -e "${GREEN}✓ $screen${NC}"
  else
    echo -e "${YELLOW}⚠ $screen (check needed)${NC}"
  fi
done

echo ""
echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}Next Steps:${NC}"
echo -e "1. Pick a module (e.g., ENTRY, DELIVERY, RIDER)"
echo -e "2. Follow the template in PRO_APP_MODERNIZATION_TEMPLATE.md"
echo -e "3. Replace hardcoded values with design system constants"
echo -e "4. Use ModernCard, ModernTile, etc."
echo -e "5. Test each file compiles"
echo -e "${BLUE}=====================================${NC}\n"

