WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '1997-01-01'
),
TotalLineItem AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    HAVING 
        SUM(ps.ps_availqty) > 100
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    p.p_name,
    p.p_brand,
    p.total_available
FROM 
    RankedOrders r
LEFT JOIN 
    TotalLineItem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierDetails s ON l.l_orderkey = s.s_suppkey
LEFT JOIN 
    FilteredParts p ON l.l_orderkey = p.p_partkey
WHERE 
    (r.o_totalprice > 500 OR l.total_revenue < 1000)
    AND p.p_brand IS NOT NULL
ORDER BY 
    r.o_orderdate DESC, 
    total_revenue DESC
LIMIT 100;