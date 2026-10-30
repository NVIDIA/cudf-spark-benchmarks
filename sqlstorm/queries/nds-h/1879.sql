WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierPartPrice AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
),
TotalLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.n_name AS supplier_nation,
    p.p_name AS part_name, 
    sp.total_supply_cost,
    ol.order_rank,
    tl.total_line_value
FROM 
    RankedOrders ol
JOIN 
    TotalLineItems tl ON ol.o_orderkey = tl.l_orderkey
JOIN 
    lineitem li ON tl.l_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    SupplierPartPrice sp ON ps.ps_partkey = sp.ps_partkey
LEFT JOIN 
    supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation r ON s.s_nationkey = r.n_nationkey
JOIN 
    part p ON li.l_partkey = p.p_partkey
WHERE 
    sp.total_supply_cost IS NOT NULL
    AND ol.order_rank <= 10
    AND p.p_retailprice BETWEEN 100.00 AND 500.00
ORDER BY 
    supplier_nation, part_name;
