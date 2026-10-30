WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps_partkey) AS unique_parts,
        SUM(ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_line_price,
        COUNT(DISTINCT lo.l_linenumber) as line_count
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)

SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(od.total_line_price) AS total_sales,
    AVG(ss.total_supply_cost) AS average_supply_cost,
    COUNT(DISTINCT ss.unique_parts) AS total_unique_parts
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    OrderDetails od ON od.l_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE price_rank <= 3)
LEFT JOIN 
    orders o ON od.l_orderkey = o.o_orderkey
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_sales DESC, average_supply_cost ASC;
