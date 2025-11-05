

// Function to calculate the discount percentage
double discountPercent(double oldPrice, double currentPrice) {
  if (oldPrice <= 0) return 0;
  return ((oldPrice - currentPrice) / oldPrice) * 100;
}
