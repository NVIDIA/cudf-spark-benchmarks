WITH High_Value_Customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
Top_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_cost) FROM (
        SELECT SUM(ps_supplycost * ps_availqty) AS total_cost
        FROM partsupp
        GROUP BY ps_suppkey
    ) AS avg_cost)
),
Top_Orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
Filtered_Items AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY l.l_orderkey
),
Customer_Order_Summary AS (
    SELECT c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(l.revenue) AS total_revenue
    FROM High_Value_Customers c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN Filtered_Items l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_name
)
SELECT
    cus.c_name,
    cus.order_count,
    cus.total_revenue,
    COALESCE((SELECT MAX(ts.total_cost) FROM Top_Suppliers ts), 0) AS max_supplier_cost,
    CASE 
        WHEN cus.total_revenue > 10000 THEN 'High Value' 
        WHEN cus.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM Customer_Order_Summary cus
WHERE cus.order_count > 5
ORDER BY cus.total_revenue DESC;