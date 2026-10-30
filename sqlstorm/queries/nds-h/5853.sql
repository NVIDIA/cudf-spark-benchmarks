WITH Supply_Cost AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        (ps_supplycost * ps_availqty) AS total_supply_cost
    FROM partsupp
),
Ranked_Suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY sc.total_supply_cost DESC) AS rank
    FROM supplier s
    JOIN Supply_Cost sc ON s.s_suppkey = sc.ps_suppkey
    JOIN part p ON p.p_partkey = sc.ps_partkey
    WHERE s.s_acctbal > 1000
),
Top_Suppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.s_acctbal
    FROM Ranked_Suppliers r
    WHERE r.rank <= 10
)
SELECT 
    c.c_custkey,
    c.c_name,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_spent,
    COUNT(DISTINCT ts.s_suppkey) AS unique_suppliers
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN Top_Suppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE o.o_orderdate >= '1997-01-01'
GROUP BY c.c_custkey, c.c_name
ORDER BY total_spent DESC
LIMIT 50;