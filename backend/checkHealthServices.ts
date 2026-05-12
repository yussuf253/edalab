import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  try {
    const categories = await prisma.healthServiceCategory.findMany();
    const labTests = await prisma.labTest.findMany();
    console.log('Health Service Categories count:', categories.length);
    console.log('Lab Tests count:', labTests.length);
    if (categories.length > 0) {
      console.log('First category:', JSON.stringify(categories[0], null, 2));
    }
    if (labTests.length > 0) {
      console.log('First lab test:', JSON.stringify(labTests[0], null, 2));
    }
  } catch (error) {
    console.error('Error fetching data:', error);
  } finally {
    await prisma.$disconnect();
  }
}

main();