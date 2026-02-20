
-- CUSTOMER BEHAVIOR ANALYSIS

CREATE DATABASE IF NOT EXISTS CustomerBehaviorAnalysis;
USE CustomerBehaviorAnalysis

-- CLEAN & OPTIMIZED TABLE STRUCTURE

DROP TABLE IF EXISTS Customers;

CREATE TABLE Customers (
    CustomerID INT,
    CustomerName VARCHAR(100),
    Age INT,
    Gender VARCHAR(20),
    PurchaseDate DATETIME,
    ProductCategory VARCHAR(50),
    ProductPrice DECIMAL(10,2),
    Quantity INT,
    TotalPurchaseAmount DECIMAL(10,2),
    PaymentMethod VARCHAR(50),
    Returns TINYINT,
    Churn TINYINT,
    PRIMARY KEY (CustomerID, PurchaseDate)
);

-- DATA QUALITY SUMMARY


SELECT
    COUNT(*) AS Total_Transactions,
    COUNT(DISTINCT CustomerID) AS Unique_Customers,
    COUNT(DISTINCT ProductCategory) AS Categories,
    MIN(PurchaseDate) AS First_Purchase,
    MAX(PurchaseDate) AS Last_Purchase,
    SUM(TotalPurchaseAmount) AS Total_Revenue
FROM Customers;


-- CUSTOMER ACQUISITION ANALYSIS


WITH first_purchase AS (
    SELECT
        CustomerID,
        MIN(PurchaseDate) AS First_Purchase_Date
    FROM Customers
    GROUP BY CustomerID
)

SELECT
    DATE_FORMAT(First_Purchase_Date, '%Y-%m') AS Acquisition_Month,
    COUNT(*) AS New_Customers
FROM first_purchase
GROUP BY Acquisition_Month
ORDER BY Acquisition_Month DESC;


-- CONVERSION & SALES METRICS


WITH totals AS (
    SELECT
        COUNT(*) AS total_transactions,
        COUNT(DISTINCT CustomerID) AS total_customers
    FROM Customers
)

SELECT
    COUNT(*) AS Total_Transactions,
    COUNT(DISTINCT CustomerID) AS Unique_Customers,
    ROUND(COUNT(*) / (SELECT total_customers FROM totals), 2) AS Avg_Transactions_Per_Customer,
    SUM(TotalPurchaseAmount) AS Total_Revenue,
    ROUND(AVG(TotalPurchaseAmount), 2) AS Avg_Order_Value,
    ROUND(SUM(Returns) / COUNT(*) * 100, 2) AS Return_Rate_Percentage
FROM Customers;


-- SALES PERFORMANCE BY CATEGORY


SELECT
    ProductCategory,
    COUNT(*) AS Transactions,
    COUNT(DISTINCT CustomerID) AS Customers,
    SUM(TotalPurchaseAmount) AS Revenue,
    ROUND(AVG(TotalPurchaseAmount), 2) AS Avg_Order_Value,
    ROUND(SUM(Returns) / COUNT(*) * 100, 2) AS Return_Rate
FROM Customers
GROUP BY ProductCategory
ORDER BY Revenue DESC;


-- MONTHLY SALES TREND


SELECT
    DATE_FORMAT(PurchaseDate, '%Y-%m') AS Sales_Month,
    COUNT(*) AS Transactions,
    SUM(TotalPurchaseAmount) AS Revenue,
    ROUND(AVG(TotalPurchaseAmount), 2) AS Avg_Order_Value
FROM Customers
GROUP BY Sales_Month
ORDER BY Sales_Month DESC;


-- CUSTOMER SEGMENTATION


WITH customer_metrics AS (
    SELECT
        CustomerID,
        COUNT(*) AS Transaction_Count,
        SUM(TotalPurchaseAmount) AS Total_Spent,
        MAX(PurchaseDate) AS Last_Purchase
    FROM Customers
    GROUP BY CustomerID
),
ranked_customers AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY Total_Spent DESC) AS Value_Quartile
    FROM customer_metrics
)

SELECT
    CASE
        WHEN Value_Quartile = 1 THEN 'High Value'
        WHEN Value_Quartile = 2 THEN 'Mid-High Value'
        WHEN Value_Quartile = 3 THEN 'Mid-Low Value'
        ELSE 'Low Value'
    END AS Customer_Segment,
    COUNT(*) AS Customers,
    ROUND(AVG(Total_Spent),2) AS Avg_Spent,
    ROUND(AVG(Transaction_Count),2) AS Avg_Transactions
FROM ranked_customers
GROUP BY Customer_Segment
ORDER BY Avg_Spent DESC;


-- CHURN ANALYSIS


SELECT
    Churn,
    COUNT(DISTINCT CustomerID) AS Customers,
    ROUND(COUNT(DISTINCT CustomerID) /
        (SELECT COUNT(DISTINCT CustomerID) FROM Customers) * 100, 2) AS Percentage,
    SUM(TotalPurchaseAmount) AS Revenue,
    ROUND(AVG(TotalPurchaseAmount),2) AS Avg_Order_Value
FROM Customers
GROUP BY Churn;


-- CHURN BY AGE GROUP


SELECT
    CASE
        WHEN Age < 25 THEN '18-24'
        WHEN Age < 35 THEN '25-34'
        WHEN Age < 45 THEN '35-44'
        WHEN Age < 55 THEN '45-54'
        WHEN Age < 65 THEN '55-64'
        ELSE '65+'
    END AS Age_Group,
    COUNT(DISTINCT CustomerID) AS Total_Customers,
    COUNT(DISTINCT CASE WHEN Churn = 1 THEN CustomerID END) AS Churned,
    ROUND(COUNT(DISTINCT CASE WHEN Churn = 1 THEN CustomerID END)
          / COUNT(DISTINCT CustomerID) * 100, 2) AS Churn_Rate
FROM Customers
GROUP BY Age_Group
ORDER BY Churn_Rate DESC;