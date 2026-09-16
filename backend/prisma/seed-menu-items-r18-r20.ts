/**
 * Adds 50 menu items to each of Lados (r18), Aska Tacos (r19) and
 * SOHO Café (r20) in the production database. Idempotent: items use
 * deterministic ids (food-r18-1 ... food-r20-50) and upsert.
 *
 * Run: npx tsx seed-menu-items-r18-r20.ts
 *
 * Each restaurant gets its own set of menu categories (created via upsert
 * before the items) and every item is explicitly assigned to one of them.
 * buildNameToCategory() validates at seed time that all 50 item names per
 * restaurant are covered exactly once, so a missing/misnamed item fails fast.
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

type ItemSpec = { name: string; description: string; price: number; popular?: boolean; customizations?: string[] };

const ladosItems: ItemSpec[] = [
  { name: 'Classic Lados Burger', description: 'Flame-grilled beef patty with lettuce, tomato and house sauce on a toasted bun.', price: 800, popular: true, customizations: ['Extra cheese', 'No onions'] },
  { name: 'Double Cheeseburger', description: 'Two beef patties with double cheddar, pickles and smoky burger sauce.', price: 1100, popular: true, customizations: ['Extra patty', 'No pickles'] },
  { name: 'Spicy Chicken Burger', description: 'Crispy chicken fillet tossed in hot sauce with cool mayo and slaw.', price: 850, popular: true, customizations: ['Extra spicy', 'Mild'] },
  { name: 'Crispy Fish Burger', description: 'Golden breaded fish fillet with tartar sauce and crisp lettuce.', price: 900, customizations: ['Extra tartar'] },
  { name: 'Veggie Burger', description: 'Grilled vegetable and chickpea patty with avocado and garlic mayo.', price: 750, customizations: ['Add avocado'] },
  { name: 'Bacon Cheeseburger', description: 'Beef patty topped with crispy bacon strips and melted cheddar.', price: 1150, popular: true, customizations: ['Extra bacon'] },
  { name: 'Mushroom Swiss Burger', description: 'Beef patty with sauteed mushrooms and melted Swiss cheese.', price: 1050, customizations: ['Extra mushrooms'] },
  { name: 'Chicken Club Burger', description: 'Grilled chicken breast with bacon, egg and mayo on a brioche bun.', price: 1000, customizations: ['No egg'] },
  { name: 'Tex-Mex Burger', description: 'Beef patty with jalapenos, nacho cheese and crunchy tortilla strips.', price: 1000, customizations: ['Extra jalapenos'] },
  { name: 'BBQ Bacon Burger', description: 'Beef patty glazed with barbecue sauce, bacon and onion rings.', price: 1150, popular: true, customizations: ['Extra BBQ sauce'] },
  { name: 'Mini Burger Trio', description: 'Three mini sliders with cheese, ketchup and pickles.', price: 1250, customizations: ['Mixed sauces'] },
  { name: 'Grilled Chicken Sandwich', description: 'Marinated grilled chicken with honey mustard and lettuce.', price: 900, customizations: ['No mayo'] },
  { name: 'Crispy Chicken Wrap', description: 'Crispy chicken strips with lettuce, cheddar and ranch in a soft wrap.', price: 750, popular: true, customizations: ['Add spicy mayo'] },
  { name: 'Beef Kebab Wrap', description: 'Seasoned minced beef kebab with onions, tomato and garlic sauce.', price: 800, customizations: ['Extra garlic sauce'] },
  { name: 'Chicken Shawarma Wrap', description: 'Marinated chicken shawarma with pickles and garlic sauce.', price: 750, popular: true, customizations: ['Extra pickles'] },
  { name: 'Falafel Wrap', description: 'Crisp falafel balls with tahini, lettuce and tomato.', price: 650, customizations: ['Extra tahini'] },
  { name: 'Tuna Sandwich', description: 'Tuna salad with sweetcorn and mayo on toasted bread.', price: 600, customizations: ['No onions'] },
  { name: 'Club Sandwich', description: 'Triple-decker with chicken, egg, cheese and fresh vegetables.', price: 950, customizations: ['No egg'] },
  { name: 'Philly Cheesesteak', description: 'Sliced beef with melted cheese, peppers and onions in a soft roll.', price: 1200, popular: true, customizations: ['Extra cheese'] },
  { name: 'Hot Dog Classic', description: 'Grilled sausage with ketchup, mustard and crispy onions.', price: 500, customizations: ['Add cheese'] },
  { name: 'French Fries (Regular)', description: 'Golden crispy fries with a pinch of sea salt.', price: 300, customizations: ['Extra salt'] },
  { name: 'French Fries (Large)', description: 'Large portion of golden crispy fries.', price: 450, popular: true, customizations: ['Add cheese sauce'] },
  { name: 'Cheesy Loaded Fries', description: 'Fries topped with melted cheddar sauce and crispy onions.', price: 650, popular: true, customizations: ['Add jalapenos'] },
  { name: 'Chicken Nuggets (6 pcs)', description: 'Six crispy chicken nuggets with a dip of your choice.', price: 550, customizations: ['BBQ dip', 'Ketchup'] },
  { name: 'Chicken Wings (6 pcs)', description: 'Buffalo-style chicken wings with blue cheese dip.', price: 700, popular: true, customizations: ['Extra spicy', 'BBQ glaze'] },
  { name: 'Onion Rings', description: 'Crispy battered onion rings with ranch dip.', price: 400, customizations: ['Extra ranch'] },
  { name: 'Mozzarella Sticks', description: 'Golden mozzarella sticks with marinara dipping sauce.', price: 550, customizations: ['Extra marinara'] },
  { name: 'Coleslaw', description: 'Fresh creamy coleslaw side salad.', price: 250, customizations: [] },
  { name: 'Garden Side Salad', description: 'Mixed greens, tomato, cucumber with vinaigrette.', price: 350, customizations: ['No onions'] },
  { name: 'Coca-Cola (33cl)', description: 'Chilled classic Coca-Cola can.', price: 250, customizations: [] },
  { name: 'Fanta Orange (33cl)', description: 'Chilled Fanta Orange can.', price: 250, customizations: [] },
  { name: 'Sprite (33cl)', description: 'Chilled Sprite can.', price: 250, customizations: [] },
  { name: 'Bottled Water (50cl)', description: 'Still mineral water.', price: 150, customizations: [] },
  { name: 'Fresh Orange Juice', description: 'Freshly squeezed orange juice.', price: 400, popular: true, customizations: ['Pulp free'] },
  { name: 'Mango Smoothie', description: 'Creamy mango smoothie blended with yogurt.', price: 500, customizations: ['Extra mango'] },
  { name: 'Iced Tea (Peach)', description: 'Refreshing peach iced tea over ice.', price: 300, customizations: ['Less sugar'] },
  { name: 'Chocolate Milkshake', description: 'Thick chocolate milkshake with whipped cream.', price: 550, popular: true, customizations: ['Extra chocolate'] },
  { name: 'Vanilla Milkshake', description: 'Classic vanilla milkshake with whipped cream.', price: 550, customizations: ['Add caramel'] },
  { name: 'Strawberry Milkshake', description: 'Strawberry milkshake blended with real fruit.', price: 550, customizations: ['Extra strawberries'] },
  { name: 'Espresso', description: 'Double shot of rich espresso.', price: 250, customizations: [] },
  { name: 'Cappuccino', description: 'Espresso with steamed milk and foam.', price: 350, customizations: ['Decaf'] },
  { name: 'Cafe au Lait', description: 'Half coffee, half hot milk.', price: 300, customizations: [] },
  { name: 'Hot Chocolate', description: 'Creamy hot chocolate topped with foam.', price: 400, customizations: ['With marshmallows'] },
  { name: 'Chocolate Brownie', description: 'Fudgy chocolate brownie square.', price: 450, popular: true, customizations: ['Warm it up'] },
  { name: 'Chocolate Chip Cookie', description: 'Soft-baked chocolate chip cookie.', price: 200, customizations: [] },
  { name: 'Apple Pie Slice', description: 'Warm cinnamon apple pie slice.', price: 400, customizations: ['With ice cream'] },
  { name: 'Ice Cream Sundae', description: 'Vanilla sundae with chocolate sauce and nuts.', price: 500, customizations: ['Extra sauce'] },
  { name: 'Chicken Family Box', description: '8 wings, 8 nuggets, 2 fries and 2 drinks to share.', price: 2800, popular: true, customizations: ['Extra dips'] },
  { name: 'Lados Combo Meal', description: 'Signature burger, regular fries and a soft drink.', price: 1300, popular: true, customizations: ['Upgrade to large'] },
  { name: 'Kids Meal (Burger + Juice)', description: 'Mini burger, small fries and a juice box with a toy.', price: 800, customizations: [] },
];

const askaTacosItems: ItemSpec[] = [
  { name: 'Tacos Pollo', description: 'Grilled marinated chicken with fries, cheese sauce and algerienne sauce wrapped in flour tortilla.', price: 900, popular: true, customizations: ['Extra cheese sauce', 'Spicy'] },
  { name: 'Tacos Viande Hachee', description: 'Seasoned minced beef with fries, cheese and mayo-taco sauce.', price: 950, popular: true, customizations: ['Extra meat'] },
  { name: 'Tacos Mixte', description: 'Half chicken, half minced beef with cheese sauce and fries.', price: 1050, popular: true, customizations: ['Add jalapenos'] },
  { name: 'Tacos Kefta', description: 'Spiced kefta meatballs with melted cheese and tomato sauce.', price: 950, customizations: ['Extra spicy'] },
  { name: 'Tacos Escalope', description: 'Breaded chicken escalope with cheese and garlic sauce.', price: 950, customizations: ['No sauce'] },
  { name: 'Tacos Nuggets', description: 'Crispy chicken nuggets with cheddar sauce and fries.', price: 900, customizations: ['BBQ sauce'] },
  { name: 'Tacos Cordon Bleu', description: 'Cordon bleu slices with cheese sauce and fries.', price: 1000, customizations: [] },
  { name: 'Tacos Merguez', description: 'Grilled merguez sausage with harissa and cheese.', price: 1000, popular: true, customizations: ['Extra harissa'] },
  { name: 'Tacos 3 Viandes', description: 'Chicken, minced beef and merguez with double cheese.', price: 1300, popular: true, customizations: ['Extra cheese'] },
  { name: 'Tacos Vegetarien', description: 'Grilled vegetables, falafel and cheese sauce.', price: 800, customizations: ['Extra falafel'] },
  { name: 'Tacos Fromage', description: 'Triple cheese blend with potato wedges in a tortilla.', price: 850, customizations: ['Add cheddar'] },
  { name: 'Tacos Algérien', description: 'Classic French-style tacos with algerienne sauce and cheese.', price: 900, customizations: ['Extra sauce'] },
  { name: 'Mini Tacos Enfant', description: 'Kid-sized tacos with chicken and mild cheese sauce.', price: 550, customizations: ['No sauce'] },
  { name: 'Tacos XXL Famille', description: 'Sharing-size tacos with three meats and double cheese.', price: 2500, popular: true, customizations: ['Cut in 4'] },
  { name: 'Burrito Poulet', description: 'Flour tortilla bowl with rice, beans, chicken and salsa.', price: 1000, customizations: ['Extra salsa'] },
  { name: 'Burrito Boeuf', description: 'Beef burrito with rice, black beans, cheese and sour cream.', price: 1100, customizations: ['No sour cream'] },
  { name: 'Quesadilla Fromage', description: 'Grilled tortilla filled with melted cheese blend.', price: 700, customizations: ['Add chicken'] },
  { name: 'Quesadilla Poulet', description: 'Grilled tortilla with chicken, cheese and peppers.', price: 900, customizations: ['Extra peppers'] },
  { name: 'Nachos Suprême', description: 'Tortilla chips with nacho cheese, salsa and jalapenos.', price: 800, popular: true, customizations: ['Extra jalapenos'] },
  { name: 'Nachos Guacamole', description: 'Tortilla chips with guacamole and cheese sauce.', price: 850, customizations: ['Extra guacamole'] },
  { name: 'Frites Nature', description: 'Classic golden fries.', price: 300, customizations: [] },
  { name: 'Frites Cheddar', description: 'Fries smothered in cheddar cheese sauce.', price: 500, customizations: ['Extra cheese'] },
  { name: 'Potato Wedges', description: 'Seasoned potato wedges with sour cream dip.', price: 450, customizations: [] },
  { name: 'Chicken Wings (6 pcs)', description: 'Spicy glazed wings with ranch dip.', price: 700, customizations: ['Extra spicy'] },
  { name: 'Mozzarella Sticks', description: 'Breaded mozzarella with marinara sauce.', price: 550, customizations: [] },
  { name: 'Salade César', description: 'Romaine, croutons, parmesan and caesar dressing.', price: 700, customizations: ['Add chicken'] },
  { name: 'Coca-Cola (33cl)', description: 'Chilled Coca-Cola can.', price: 250, customizations: [] },
  { name: 'Fanta Orange (33cl)', description: 'Chilled Fanta Orange can.', price: 250, customizations: [] },
  { name: 'Hawai (33cl)', description: 'Chilled Hawaiian tropical soda.', price: 250, customizations: [] },
  { name: 'Bottled Water (50cl)', description: 'Still mineral water.', price: 150, customizations: [] },
  { name: 'Jus d\'Avocat', description: 'Creamy avocado milkshake, Djiboutian style.', price: 500, popular: true, customizations: ['Less sugar'] },
  { name: 'Jus de Mangue', description: 'Fresh mango juice.', price: 400, customizations: [] },
  { name: 'Citronnade Maison', description: 'House lemonade with mint.', price: 350, customizations: ['Extra mint'] },
  { name: 'Milkshake Vanille', description: 'Vanilla milkshake with whipped cream.', price: 550, customizations: [] },
  { name: 'Milkshake Chocolat', description: 'Chocolate milkshake with whipped cream.', price: 550, popular: true, customizations: ['Extra chocolate'] },
  { name: 'Thé à la Menthe', description: 'Traditional mint tea, sweetened.', price: 200, customizations: ['Less sugar'] },
  { name: 'Café Expresso', description: 'Double espresso shot.', price: 250, customizations: [] },
  { name: 'Cappuccino', description: 'Espresso with steamed milk.', price: 350, customizations: [] },
  { name: 'Tiramisu', description: 'Classic coffee-flavoured Italian dessert.', price: 500, customizations: [] },
  { name: 'Brownie Chocolat', description: 'Fudgy chocolate brownie.', price: 450, customizations: ['Warm'] },
  { name: 'Cookie Chocolat', description: 'Soft chocolate chip cookie.', price: 200, customizations: [] },
  { name: 'Tacos Combo Menú', description: 'Any tacos, fries and a soft drink.', price: 1400, popular: true, customizations: ['Upgrade drink'] },
  { name: 'Double Tacos Combo', description: 'Two tacos, large fries and two drinks.', price: 2400, customizations: [] },
  { name: 'Family Tacos Box', description: 'Four tacos, two fries and four drinks.', price: 4500, popular: true, customizations: ['Mixed meats'] },
  { name: 'Assiette Grill Mixte', description: 'Grilled chicken, kofta and merguez with fries and salad.', price: 1600, customizations: ['Extra sauce'] },
  { name: 'Assiette Poulet Grillé', description: 'Grilled chicken plate with fries and garlic sauce.', price: 1300, customizations: [] },
  { name: 'Wrap Frites Omelette', description: 'Omelette and fries wrap, Djiboutian street style.', price: 500, customizations: ['Add cheese'] },
  { name: 'Chawarma Mixte', description: 'Chicken and beef shawarma with pickles and garlic sauce.', price: 800, popular: true, customizations: ['Extra pickles'] },
  { name: 'Poutine Style Fries', description: 'Fries topped with cheese curds and brown gravy.', price: 700, customizations: ['Extra gravy'] },
  { name: 'Salade de Fruits', description: 'Fresh seasonal fruit salad cup.', price: 400, customizations: [] },
];

const sohoCafeItems: ItemSpec[] = [
  { name: 'SOHO Breakfast Platter', description: 'Eggs any style, toast, sausage, baked beans and hash browns.', price: 950, popular: true, customizations: ['Eggs scrambled', 'Eggs fried'] },
  { name: 'Avocado Toast', description: 'Sourdough toast with smashed avocado, chili flakes and poached egg.', price: 800, popular: true, customizations: ['Add egg', 'No chili'] },
  { name: 'Eggs Benedict', description: 'Poached eggs and ham on an English muffin with hollandaise.', price: 1000, customizations: ['No ham'] },
  { name: 'Pancake Stack', description: 'Three fluffy pancakes with maple syrup and butter.', price: 750, popular: true, customizations: ['Add banana', 'Add chocolate chips'] },
  { name: 'French Toast', description: 'Brioche French toast with cinnamon and powdered sugar.', price: 700, customizations: ['Add syrup'] },
  { name: 'Omelette au Fromage', description: 'Three-egg omelette with melted cheese and herbs.', price: 650, customizations: ['Add mushrooms'] },
  { name: 'Omelette Végétarienne', description: 'Three-egg omelette with peppers, onion, tomato and cheese.', price: 700, customizations: ['No onions'] },
  { name: 'Croissant Jambon-Fromage', description: 'Butter croissant filled with ham and melted cheese.', price: 550, customizations: ['Warm it up'] },
  { name: 'Beignets Maison', description: 'Freshly made doughnuts dusted with sugar.', price: 400, customizations: [] },
  { name: 'Granola Bowl', description: 'Greek yogurt, granola, honey and fresh fruit.', price: 650, customizations: ['Extra honey'] },
  { name: 'Club Sandwich', description: 'Triple-decker chicken, bacon, egg and salad with fries.', price: 900, popular: true, customizations: ['No bacon'] },
  { name: 'Croque Monsieur', description: 'Grilled ham and cheese sandwich with bechamel.', price: 650, customizations: ['Add egg'] },
  { name: 'Burger du Café', description: 'Beef burger with cheddar, lettuce and house sauce, served with fries.', price: 1000, customizations: ['Extra cheese'] },
  { name: 'Poulet Grillé Plat', description: 'Grilled chicken breast with rice or fries and salad.', price: 1200, customizations: ['Extra sauce'] },
  { name: 'Salade César', description: 'Romaine, grilled chicken, parmesan, croutons and caesar dressing.', price: 850, customizations: ['Dressing on the side'] },
  { name: 'Salade Méditerranéenne', description: 'Feta, olives, cucumber, tomato and olive oil.', price: 750, customizations: ['Add tuna'] },
  { name: 'Pasta Carbonara', description: 'Spaghetti with creamy bacon and parmesan sauce.', price: 1100, popular: true, customizations: ['Extra parmesan'] },
  { name: 'Pasta Bolognaise', description: 'Spaghetti with slow-cooked beef ragu.', price: 1100, customizations: ['Extra sauce'] },
  { name: 'Pizza Margherita', description: 'Tomato, mozzarella and basil on thin crust.', price: 1000, customizations: ['Extra cheese'] },
  { name: 'Pizza Diavola', description: 'Spicy salami and mozzarella pizza.', price: 1150, customizations: ['Extra spicy'] },
  { name: 'Sandwich Poulet Avocat', description: 'Grilled chicken and avocado on toasted bread with fries.', price: 850, customizations: ['No mayo'] },
  { name: 'Frites Maison', description: 'Hand-cut fries with house seasoning.', price: 350, customizations: ['Extra salt'] },
  { name: 'Soupe du Jour', description: 'Fresh homemade soup of the day with bread.', price: 450, customizations: [] },
  { name: 'Quiche Lorraine', description: 'Quiche with bacon and gruyere, served with salad.', price: 700, customizations: ['Warm'] },
  { name: 'Espresso', description: 'Rich double espresso shot.', price: 250, customizations: [] },
  { name: 'Cappuccino', description: 'Espresso with velvety steamed milk foam.', price: 400, popular: true, customizations: ['Decaf', 'Extra foam'] },
  { name: 'Latte', description: 'Espresso with generous steamed milk.', price: 400, customizations: ['Iced', 'Vanilla syrup'] },
  { name: 'Americano', description: 'Espresso topped with hot water.', price: 300, customizations: ['Iced'] },
  { name: 'Mocha', description: 'Espresso with chocolate and steamed milk.', price: 450, popular: true, customizations: ['Extra chocolate'] },
  { name: 'Caramel Macchiato', description: 'Vanilla latte topped with caramel drizzle.', price: 500, customizations: ['Extra caramel'] },
  { name: 'Café Turc', description: 'Traditional Turkish coffee.', price: 300, customizations: [] },
  { name: 'Chocolat Chaud', description: 'Rich hot chocolate with whipped cream.', price: 450, customizations: ['With marshmallows'] },
  { name: 'Thé à la Menthe', description: 'Moroccan-style mint tea.', price: 200, customizations: ['Less sugar'] },
  { name: 'Fresh Orange Juice', description: 'Freshly squeezed orange juice.', price: 450, popular: true, customizations: ['Pulp free'] },
  { name: 'Avocado Milkshake', description: 'Creamy avocado shake with honey.', price: 550, customizations: ['Extra honey'] },
  { name: 'Mango Smoothie', description: 'Mango blended with yogurt and honey.', price: 550, customizations: ['Extra mango'] },
  { name: 'Berry Smoothie', description: 'Mixed berries, banana and yogurt.', price: 600, customizations: ['No banana'] },
  { name: 'Iced Latte', description: 'Chilled espresso with milk over ice.', price: 450, popular: true, customizations: ['Extra shot'] },
  { name: 'Lemon Iced Tea', description: 'House iced tea with lemon.', price: 350, customizations: ['Less sugar'] },
  { name: 'Sparkling Water', description: 'Chilled sparkling mineral water.', price: 200, customizations: [] },
  { name: 'Tiramisu Maison', description: 'House-made classic tiramisu.', price: 550, popular: true, customizations: [] },
  { name: 'Cheesecake New York', description: 'Creamy baked cheesecake with berry coulis.', price: 600, customizations: [] },
  { name: 'Fondant au Chocolat', description: 'Warm chocolate fondant with molten centre.', price: 600, popular: true, customizations: ['With ice cream'] },
  { name: 'Crêpe Sucrée', description: 'Thin crepe with sugar or Nutella.', price: 450, customizations: ['Add banana'] },
  { name: 'Cookie Chocolat', description: 'Warm chocolate chip cookie.', price: 200, customizations: [] },
  { name: 'Carrot Cake Slice', description: 'Moist carrot cake with cream cheese frosting.', price: 500, customizations: [] },
  { name: 'Brunch Duo SOHO', description: 'Two coffees, two pastries and a shared omelette platter.', price: 2200, popular: true, customizations: [] },
  { name: 'Café Gourmand', description: 'Espresso served with three mini desserts.', price: 650, customizations: [] },
  { name: 'Plateau Petit-Déjeuner Solo', description: 'Coffee or tea, juice, croissant and bread with jam.', price: 800, customizations: ['Coffee', 'Tea'] },
  { name: 'Formule Déjeuner', description: 'Soup or salad, main dish of the day and a drink.', price: 1500, popular: true, customizations: [] },
];

function slugId(restaurantId: string, n: number) {
  return `food-${restaurantId}-${String(n).padStart(2, '0')}`;
}

// Menu categories per restaurant. Where a category id already existed from
// an earlier run (r18-burgers, r18-sides, r19-tacos, r19-sides, r20-cafe,
// r20-drinks) it is reused so we don't leave orphan rows behind.
type CategorySpec = { id: string; name: string; sortOrder: number };

const categoriesByRestaurant: Record<string, CategorySpec[]> = {
  r18: [
    { id: 'r18-burgers', name: 'Burgers', sortOrder: 0 },
    { id: 'r18-wraps-sandwiches', name: 'Wraps & Sandwiches', sortOrder: 1 },
    { id: 'r18-sides', name: 'Sides & Snacks', sortOrder: 2 },
    { id: 'r18-drinks', name: 'Drinks', sortOrder: 3 },
    { id: 'r18-shakes-coffee', name: 'Shakes & Coffee', sortOrder: 4 },
    { id: 'r18-desserts', name: 'Desserts', sortOrder: 5 },
    { id: 'r18-combos', name: 'Combos & Meals', sortOrder: 6 },
  ],
  r19: [
    { id: 'r19-tacos', name: 'Tacos', sortOrder: 0 },
    { id: 'r19-burritos-quesadillas', name: 'Burritos & Quesadillas', sortOrder: 1 },
    { id: 'r19-sides', name: 'Nachos & Sides', sortOrder: 2 },
    { id: 'r19-salads-plates', name: 'Salads & Plates', sortOrder: 3 },
    { id: 'r19-drinks', name: 'Drinks', sortOrder: 4 },
    { id: 'r19-coffee-shakes', name: 'Coffee & Shakes', sortOrder: 5 },
    { id: 'r19-desserts', name: 'Desserts', sortOrder: 6 },
    { id: 'r19-combos', name: 'Combos', sortOrder: 7 },
  ],
  r20: [
    { id: 'r20-breakfast', name: 'Breakfast & Brunch', sortOrder: 0 },
    { id: 'r20-sandwiches-salads', name: 'Sandwiches & Salads', sortOrder: 1 },
    { id: 'r20-mains', name: 'Mains', sortOrder: 2 },
    { id: 'r20-cafe', name: 'Coffee & Hot Drinks', sortOrder: 3 },
    { id: 'r20-drinks', name: 'Cold Drinks & Smoothies', sortOrder: 4 },
    { id: 'r20-desserts', name: 'Desserts', sortOrder: 5 },
    { id: 'r20-formules', name: 'Formules & Menus', sortOrder: 6 },
  ],
};

// Every item name must be assigned to exactly one category. Names must match
// the arrays above exactly; buildNameToCategory() fails loudly at runtime if
// an item is unmapped, mapped twice, or a mapped name doesn't exist.
const itemCategoryNames: Record<string, Record<string, string[]>> = {
  r18: {
    'r18-burgers': [
      'Classic Lados Burger', 'Double Cheeseburger', 'Spicy Chicken Burger', 'Crispy Fish Burger', 'Veggie Burger',
      'Bacon Cheeseburger', 'Mushroom Swiss Burger', 'Chicken Club Burger', 'Tex-Mex Burger', 'BBQ Bacon Burger', 'Mini Burger Trio',
    ],
    'r18-wraps-sandwiches': [
      'Grilled Chicken Sandwich', 'Crispy Chicken Wrap', 'Beef Kebab Wrap', 'Chicken Shawarma Wrap', 'Falafel Wrap',
      'Tuna Sandwich', 'Club Sandwich', 'Philly Cheesesteak', 'Hot Dog Classic',
    ],
    'r18-sides': [
      'French Fries (Regular)', 'French Fries (Large)', 'Cheesy Loaded Fries', 'Chicken Nuggets (6 pcs)', 'Chicken Wings (6 pcs)',
      'Onion Rings', 'Mozzarella Sticks', 'Coleslaw', 'Garden Side Salad',
    ],
    'r18-drinks': ['Coca-Cola (33cl)', 'Fanta Orange (33cl)', 'Sprite (33cl)', 'Bottled Water (50cl)', 'Fresh Orange Juice', 'Mango Smoothie', 'Iced Tea (Peach)'],
    'r18-shakes-coffee': ['Chocolate Milkshake', 'Vanilla Milkshake', 'Strawberry Milkshake', 'Espresso', 'Cappuccino', 'Cafe au Lait', 'Hot Chocolate'],
    'r18-desserts': ['Chocolate Brownie', 'Chocolate Chip Cookie', 'Apple Pie Slice', 'Ice Cream Sundae'],
    'r18-combos': ['Chicken Family Box', 'Lados Combo Meal', 'Kids Meal (Burger + Juice)'],
  },
  r19: {
    'r19-tacos': [
      'Tacos Pollo', 'Tacos Viande Hachee', 'Tacos Mixte', 'Tacos Kefta', 'Tacos Escalope', 'Tacos Nuggets',
      'Tacos Cordon Bleu', 'Tacos Merguez', 'Tacos 3 Viandes', 'Tacos Vegetarien', 'Tacos Fromage', 'Tacos Algérien',
      'Mini Tacos Enfant', 'Tacos XXL Famille',
    ],
    'r19-burritos-quesadillas': ['Burrito Poulet', 'Burrito Boeuf', 'Quesadilla Fromage', 'Quesadilla Poulet'],
    'r19-sides': [
      'Nachos Suprême', 'Nachos Guacamole', 'Frites Nature', 'Frites Cheddar', 'Potato Wedges',
      'Chicken Wings (6 pcs)', 'Mozzarella Sticks', 'Poutine Style Fries',
    ],
    'r19-salads-plates': ['Salade César', 'Assiette Grill Mixte', 'Assiette Poulet Grillé', 'Wrap Frites Omelette', 'Chawarma Mixte'],
    'r19-drinks': ['Coca-Cola (33cl)', 'Fanta Orange (33cl)', 'Hawai (33cl)', 'Bottled Water (50cl)', "Jus d'Avocat", 'Jus de Mangue', 'Citronnade Maison'],
    'r19-coffee-shakes': ['Milkshake Vanille', 'Milkshake Chocolat', 'Thé à la Menthe', 'Café Expresso', 'Cappuccino'],
    'r19-desserts': ['Tiramisu', 'Brownie Chocolat', 'Cookie Chocolat', 'Salade de Fruits'],
    'r19-combos': ['Tacos Combo Menú', 'Double Tacos Combo', 'Family Tacos Box'],
  },
  r20: {
    'r20-breakfast': [
      'SOHO Breakfast Platter', 'Avocado Toast', 'Eggs Benedict', 'Pancake Stack', 'French Toast',
      'Omelette au Fromage', 'Omelette Végétarienne', 'Croissant Jambon-Fromage', 'Beignets Maison', 'Granola Bowl',
      'Quiche Lorraine', 'Plateau Petit-Déjeuner Solo',
    ],
    'r20-sandwiches-salads': ['Club Sandwich', 'Croque Monsieur', 'Sandwich Poulet Avocat', 'Salade César', 'Salade Méditerranéenne', 'Soupe du Jour', 'Frites Maison'],
    'r20-mains': ['Burger du Café', 'Poulet Grillé Plat', 'Pasta Carbonara', 'Pasta Bolognaise', 'Pizza Margherita', 'Pizza Diavola', 'Formule Déjeuner'],
    'r20-cafe': ['Espresso', 'Cappuccino', 'Latte', 'Americano', 'Mocha', 'Caramel Macchiato', 'Café Turc', 'Chocolat Chaud', 'Thé à la Menthe'],
    'r20-drinks': ['Fresh Orange Juice', 'Avocado Milkshake', 'Mango Smoothie', 'Berry Smoothie', 'Iced Latte', 'Lemon Iced Tea', 'Sparkling Water'],
    'r20-desserts': ['Tiramisu Maison', 'Cheesecake New York', 'Fondant au Chocolat', 'Crêpe Sucrée', 'Cookie Chocolat', 'Carrot Cake Slice', 'Café Gourmand'],
    'r20-formules': ['Brunch Duo SOHO'],
  },
};

function buildNameToCategory(restaurantId: string, items: ItemSpec[]) {
  const byCategory = itemCategoryNames[restaurantId];
  if (!byCategory) throw new Error(`No category mapping defined for ${restaurantId}`);
  const map = new Map<string, string>();
  for (const [categoryId, names] of Object.entries(byCategory)) {
    for (const name of names) {
      if (map.has(name)) throw new Error(`${restaurantId}: item "${name}" is assigned to multiple categories`);
      map.set(name, categoryId);
    }
  }
  for (const spec of items) {
    if (!map.has(spec.name)) throw new Error(`${restaurantId}: no category assigned for item "${spec.name}"`);
  }
  if (map.size !== items.length) {
    throw new Error(`${restaurantId}: category mapping covers ${map.size} names but restaurant has ${items.length} items`);
  }
  return map;
}

async function seedCategories(restaurantId: string) {
  const categories = categoriesByRestaurant[restaurantId];
  for (const category of categories) {
    await prisma.restaurantMenuCategory.upsert({
      where: { id: category.id },
      update: { restaurantId, name: category.name, sortOrder: category.sortOrder },
      create: { id: category.id, restaurantId, name: category.name, sortOrder: category.sortOrder },
    });
  }
  console.log(`Seeded ${categories.length} menu categories for ${restaurantId}`);
}

async function seedRestaurant(restaurantId: string, items: ItemSpec[]) {
  if (items.length !== 50) throw new Error(`${restaurantId} must have 50 items, got ${items.length}`);
  await seedCategories(restaurantId);
  const nameToCategory = buildNameToCategory(restaurantId, items);
  for (let i = 0; i < items.length; i++) {
    const spec = items[i];
    const id = slugId(restaurantId, i + 1);
    const categoryId = nameToCategory.get(spec.name)!;
    await prisma.restaurantMenuItem.upsert({
      where: { id },
      update: { name: spec.name, description: spec.description, price: spec.price, restaurantId, categoryId, isPopular: spec.popular ?? false, customizationsJson: spec.customizations ?? [] },
      create: {
        id,
        restaurantId,
        categoryId,
        name: spec.name,
        description: spec.description,
        price: spec.price,
        imageUrl: null,
        isPopular: spec.popular ?? false,
        isAvailable: true,
        customizationsJson: spec.customizations ?? [],
      },
    });
  }
  console.log(`Seeded 50 items for ${restaurantId}`);
}

async function main() {
  // seedRestaurant upserts each restaurant's categories before its items,
  // so the category rows exist before any item references them.
  await seedRestaurant('r18', ladosItems);
  await seedRestaurant('r19', askaTacosItems);
  await seedRestaurant('r20', sohoCafeItems);
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
