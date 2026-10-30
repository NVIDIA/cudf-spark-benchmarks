
WITH  RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey
),
CustomerSegments AS (
    SELECT 
        c.c_custkey,
        CASE 
            WHEN c.c_acctbal > 10000 THEN 'High Value'
            WHEN c.c_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM 
        customer c
),
EligibleSuppliers AS (
    SELECT DISTINCT
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.rank_within_nation <= 5
),
FinalReport AS (
    SELECT 
        cs.customer_segment,
        e.r_name AS supplier_region,
        e.s_name AS supplier_name,
        COALESCE(SUM(hv.total_order_value), 0) AS total_sales,
        COUNT(hv.o_orderkey) AS order_count,
        COUNT(DISTINCT e.s_suppkey) AS unique_suppliers
    FROM 
        CustomerSegments cs
    LEFT JOIN 
        HighValueOrders hv ON cs.c_custkey = hv.o_orderkey
    RIGHT JOIN 
        EligibleSuppliers e ON cs.c_custkey = e.s_suppkey
    GROUP BY 
        cs.customer_segment, e.r_name, e.s_name
)
SELECT 
    f.customer_segment,
    f.supplier_region,
    f.supplier_name,
    f.total_sales,
    f.order_count,
    f.unique_suppliers
FROM 
    FinalReport f
WHERE 
    f.total_sales > 0
ORDER BY 
    f.customer_segment DESC, f.total_sales DESC;
