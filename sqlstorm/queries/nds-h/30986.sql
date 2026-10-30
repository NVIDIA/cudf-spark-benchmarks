WITH  RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS high_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    AVG(cs.total_spent) AS average_spent,
    MAX(hvs.high_value) AS max_supplier_value
FROM 
    region r
JOIN 
    nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerSales cs ON ns.n_nationkey = cs.c_custkey
LEFT JOIN 
    HighValueSuppliers hvs ON cs.c_custkey = hvs.s_suppkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT ns.n_nationkey) > 1
ORDER BY 
    average_spent DESC;