WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate >= DATE '1997-01-01' AND 
        l.l_shipdate < DATE '1997-10-01' 
    GROUP BY 
        n.n_name, n.n_nationkey
),
TopSales AS (
    SELECT 
        nation_name, 
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 3
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        sum(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    T.nation_name,
    T.total_sales,
    S.s_name,
    S.total_supplycost,
    CASE 
        WHEN T.total_sales > 10000 THEN 'High'
        WHEN T.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    TopSales T
LEFT JOIN 
    SupplierDetails S ON S.total_supplycost >= T.total_sales
ORDER BY 
    T.total_sales DESC, 
    S.total_supplycost ASC;