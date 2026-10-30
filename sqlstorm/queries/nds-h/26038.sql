WITH AggregatedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    a.p_partkey,
    a.p_name,
    a.p_brand,
    a.p_type,
    a.num_suppliers,
    a.avg_supplycost,
    a.total_availqty,
    co.c_custkey,
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    co.total_revenue
FROM 
    AggregatedParts a
JOIN 
    CustomerOrders co ON a.p_brand = COALESCE(LEFT(co.c_name, LENGTH(a.p_brand)), a.p_brand)
WHERE 
    a.num_suppliers > 5
ORDER BY 
    total_revenue DESC, a.p_name ASC, co.o_orderdate DESC
LIMIT 50;