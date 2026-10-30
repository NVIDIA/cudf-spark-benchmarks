WITH SalesData AS (
    SELECT
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        AVG(s.s_acctbal) AS avg_supplier_balance
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
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        n.n_name
),
SalesRanked AS (
    SELECT 
        nation,
        total_sales,
        order_count,
        avg_order_value,
        avg_supplier_balance,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    nation,
    total_sales,
    order_count,
    avg_order_value,
    avg_supplier_balance,
    sales_rank
FROM 
    SalesRanked
WHERE 
    sales_rank <= 10
ORDER BY 
    sales_rank;