
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RevenueRanked AS (
    SELECT 
        od.o_orderkey,
        od.total_revenue,
        RANK() OVER (ORDER BY od.total_revenue DESC) AS revenue_rank
    FROM 
        OrderDetails od
),
Nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sd.nation_name,
    sd.total_parts,
    sd.total_supplycost,
    COUNT(DISTINCT rr.o_orderkey) AS orders_count,
    SUM(rr.total_revenue) AS total_revenues,
    COALESCE(MAX(rr.revenue_rank), 0) AS max_revenue_rank
FROM 
    SupplierDetails sd
LEFT JOIN 
    RevenueRanked rr ON sd.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN SupplierDetails sd2 ON sd2.s_suppkey = ps.ps_suppkey
    )
JOIN 
    Nations n ON sd.nation_name = n.n_name
GROUP BY 
    sd.nation_name, sd.total_parts, sd.total_supplycost
HAVING 
    SUM(rr.total_revenue) > 5000
ORDER BY 
    total_revenues DESC, sd.nation_name ASC;
