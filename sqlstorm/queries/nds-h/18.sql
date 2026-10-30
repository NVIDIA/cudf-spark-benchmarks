WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F' 
      AND o.o_orderdate >= '1997-01-01' 
      AND o.o_orderdate < '1998-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_retailprice,
        CASE 
            WHEN p.p_size < 20 THEN 'Small'
            WHEN p.p_size BETWEEN 20 AND 50 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM part p
    WHERE p.p_retailprice < 100.00
)
SELECT
    r.r_name,
    SUM(CASE WHEN o.order_rank = 1 THEN o.o_totalprice ELSE 0 END) AS highest_total_price,
    AVG(COALESCE(ss.total_supply_cost, 0)) AS average_supply_cost,
    pd.size_category,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM RankedOrders o
LEFT JOIN nation n ON o.o_orderkey % 5 = n.n_nationkey  
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierStats ss ON ss.parts_supplied > 10
LEFT JOIN PartDetails pd ON pd.p_partkey = o.o_orderkey % 100  
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, pd.size_category
ORDER BY highest_total_price DESC, average_supply_cost DESC;