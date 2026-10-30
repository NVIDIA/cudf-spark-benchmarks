WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(cs.total_spent) AS avg_customer_spent
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = l.l_orderkey
WHERE 
    l.l_shipdate >= '1997-01-01'
    AND (l.l_returnflag = 'R' OR l.l_linestatus = 'F')
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(l.l_extendedprice) > 100000
ORDER BY 
    total_revenue DESC
LIMIT 10;