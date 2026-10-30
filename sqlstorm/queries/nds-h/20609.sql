WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1995-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        COUNT(ps.ps_suppkey) > 2
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customers_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(NULLIF(l.l_discount, 0)) AS avg_discount,
    SUM(s.total_supply_cost) AS total_supplier_cost,
    COUNT(DISTINCT s.part_count) AS unique_parts_supplied,
    o.o_orderstatus
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierStats s ON s.s_suppkey = l.l_suppkey
JOIN 
    HighValueParts hp ON l.l_partkey = hp.p_partkey
WHERE 
    o.o_orderstatus IN ('O', 'P', 'F')
    AND (l.l_returnflag IS NULL OR l.l_returnflag != 'R')
GROUP BY 
    r.r_name, o.o_orderstatus
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    r.r_name, total_sales DESC
LIMIT 10 OFFSET 10;
