
WITH  SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) DESC) AS rank
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name 
    HAVING COUNT(o.o_orderkey) >= 5
),
NationRank AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        RANK() OVER (ORDER BY COUNT(DISTINCT s.s_suppkey) DESC) AS nation_rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    CASE 
        WHEN sc.total_supply_value > 10000000 THEN 'High Supplier Value'
        WHEN sc.total_supply_value BETWEEN 5000000 AND 10000000 THEN 'Moderate Supplier Value'
        ELSE 'Low Supplier Value' 
    END AS supplier_value_category,
    n.n_name AS supplier_nation,
    c.c_name AS customer_name,
    hd.total_spent,
    hd.order_count,
    nn.nation_rank
FROM SupplyChain sc
JOIN HighValueCustomers hd ON hd.total_spent > sc.total_supply_value
JOIN customer c ON c.c_custkey = hd.c_custkey
JOIN nation n ON n.n_nationkey = c.c_nationkey
JOIN NationRank nn ON nn.n_nationkey = n.n_nationkey
WHERE sc.rank = 1 
  AND c.c_acctbal IS NOT NULL 
  AND n.n_name IS NOT NULL
  AND (hd.total_spent IS NULL OR hd.total_spent > 1000) 
ORDER BY supplier_value_category, hd.total_spent DESC;
