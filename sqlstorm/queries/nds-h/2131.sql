WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
), SuppData AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS average_account_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.p_partkey,
    r.p_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(sd.supplier_count, 0) AS supplier_count,
    COALESCE(sd.average_account_balance, 0) AS average_account_balance,
    CASE 
        WHEN r.total_sales IS NOT NULL AND r.total_sales > 100000 THEN 'High Performer'
        WHEN r.total_sales IS NULL THEN 'No Sales'
        ELSE 'Needs Improvement' 
    END AS performance_category
FROM 
    RankedSales r
FULL OUTER JOIN 
    SuppData sd ON r.p_partkey = sd.ps_partkey
WHERE 
    COALESCE(r.total_sales, 0) + COALESCE(sd.supplier_count, 0) > 0
ORDER BY 
    performance_category DESC, total_sales DESC;