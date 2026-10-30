
WITH  RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM
        nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        n.n_name, n.n_nationkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
TopNations AS (
    SELECT
        nation_name,
        total_sales
    FROM
        RegionalSales
    WHERE
        rnk <= 3
),
SupplierInfo AS (
    SELECT
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_name
),
FinalReport AS (
    SELECT 
        tn.nation_name,
        tn.total_sales,
        COALESCE(si.total_cost, 0) AS total_cost
    FROM 
        TopNations tn
    LEFT JOIN SupplierInfo si ON si.s_name = CONCAT('Supplier of ', tn.nation_name) 
    ORDER BY 
        tn.total_sales DESC, 
        tn.nation_name
)
SELECT 
    nation_name,
    total_sales,
    total_cost,
    CASE 
        WHEN total_sales > total_cost THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM 
    FinalReport
WHERE 
    total_sales IS NOT NULL OR total_cost IS NOT NULL;
