WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
lineitem_stats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    COALESCE(ls.total_sales, 0) AS total_sales,
    COALESCE(su.part_count, 0) AS supplier_part_count,
    su.avg_supplycost,
    RANK() OVER (ORDER BY o.o_totalprice DESC) AS total_price_rank
FROM 
    ranked_orders o
LEFT JOIN 
    lineitem_stats ls ON o.o_orderkey = ls.l_orderkey
LEFT JOIN 
    supplier_summary su ON su.part_count > 0
WHERE 
    o.order_rank <= 10
ORDER BY 
    total_sales DESC, o.o_orderdate ASC;