WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
),
SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        lineitem li
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ss.total_sales) AS total_supplier_sales
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.ps_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    HAVING 
        SUM(ss.total_sales) IS NOT NULL
),
FinalReport AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(ts.total_supplier_sales) AS supplier_sales_sum,
        AVG(ts.s_acctbal) AS average_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        TopSuppliers ts ON n.n_nationkey = ts.s_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    fr.r_name,
    fr.nation_count,
    COALESCE(fr.supplier_sales_sum, 0) AS supplier_sales_sum,
    CASE 
        WHEN fr.average_acctbal IS NULL THEN 'No Data'
        ELSE CAST(fr.average_acctbal AS STRING)
    END AS average_acctbal,
    (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderstatus = 'O') AS total_orders
FROM 
    FinalReport fr
ORDER BY 
    fr.r_name;