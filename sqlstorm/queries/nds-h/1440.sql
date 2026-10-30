WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_comment LIKE '%central%'
)
SELECT 
    f.n_name,
    f.region_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    o.o_orderdate,
    o.o_totalprice,
    o.order_rank,
    od.total_line_price,
    od.total_quantity,
    ss.total_available
FROM 
    FilteredNations f
LEFT JOIN 
    supplier s ON f.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedOrders o ON s.s_suppkey = o.o_orderkey
LEFT JOIN 
    OrderDetails od ON o.o_orderkey = od.l_orderkey
JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    ss.total_parts > 5 
    AND ss.total_available IS NOT NULL
ORDER BY 
    total_line_price DESC,
    region_name ASC;