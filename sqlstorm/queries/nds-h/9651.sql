WITH Summary AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
        AVG(c.c_acctbal) AS avg_customer_balance
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey 
    WHERE 
        l_shipdate >= '1996-01-01' AND l_shipdate < '1996-12-31'
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    nation_name,
    region_name,
    total_supply_cost,
    unique_suppliers,
    avg_customer_balance
FROM 
    Summary
WHERE 
    total_supply_cost > (SELECT AVG(total_supply_cost) FROM Summary)
ORDER BY 
    total_supply_cost DESC, unique_suppliers ASC;