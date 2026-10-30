WITH  PriceBreakdown AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
), 
TotalSales AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_orders
    FROM
        lineitem l
    WHERE
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY
        l.l_partkey
), 
RankedParts AS (
    SELECT 
        pb.p_partkey, 
        pb.p_name, 
        pb.ps_supplycost, 
        ts.total_sales,
        ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM 
        PriceBreakdown pb
    JOIN 
        TotalSales ts ON pb.p_partkey = ts.l_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    rp.p_name AS part_name,
    rp.total_sales,
    rp.ps_supplycost,
    CASE 
        WHEN rp.total_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('Sales: ', CAST(rp.total_sales AS STRING))
    END AS sales_description
FROM 
    RankedParts rp
LEFT JOIN 
    supplier s ON rp.p_partkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    rp.sales_rank <= 10
ORDER BY 
    rp.total_sales DESC;