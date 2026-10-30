
WITH RankedOrders AS (
    SELECT o_orderkey, 
           o_custkey, 
           o_orderdate, 
           o_totalprice, 
           DENSE_RANK() OVER (PARTITION BY o_orderdate ORDER BY o_totalprice DESC) AS price_rank
    FROM orders
    WHERE o_orderstatus IN ('O', 'P')
),
HighValueLineItems AS (
    SELECT l.l_orderkey,
           l.l_suppkey,
           l.l_extendedprice,
           l.l_discount,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS item_rank,
           CASE 
               WHEN l.l_discount > 0.1 THEN 'High Discount' 
               WHEN l.l_discount IS NULL THEN 'No Discount' 
               ELSE 'Standard Discount' 
           END AS discount_category
    FROM lineitem l
    WHERE l.l_quantity > 10 AND l.l_returnflag = 'N'
),
SupplierNation AS (
    SELECT s.s_suppkey, 
           n.n_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, n.n_name
),
OuterJoinResults AS (
    SELECT s.n_name AS supplier_nation, 
           o.o_orderkey, 
           o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM RankedOrders o
    LEFT JOIN HighValueLineItems l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN SupplierNation s ON l.l_suppkey = s.s_suppkey
    WHERE o.o_orderdate >= '1997-01-01' 
    AND (s.total_supply_cost > 1000 OR s.total_supply_cost IS NULL)
    GROUP BY s.n_name, o.o_orderkey, o.o_totalprice
)
SELECT supplier_nation, 
       COUNT(DISTINCT o_orderkey) AS unique_orders, 
       AVG(o_totalprice) AS avg_order_value, 
       SUM(total_lineitem_value) AS total_value_sum
FROM OuterJoinResults
GROUP BY supplier_nation
HAVING AVG(o_totalprice) > (
    SELECT AVG(o_totalprice) 
    FROM orders 
    WHERE o_orderdate < '1997-01-01'
)
UNION ALL
SELECT 'Total', 
       COUNT(DISTINCT o_orderkey), 
       AVG(o_totalprice), 
       SUM(total_lineitem_value)
FROM OuterJoinResults
ORDER BY 1;
