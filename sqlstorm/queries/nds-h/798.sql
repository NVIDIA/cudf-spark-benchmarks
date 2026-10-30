
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
SupplierProfitMargins AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        SUM(l.l_extendedprice * l.l_tax) AS total_tax_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.s_name,
    r.total_sales,
    r.order_count,
    c.total_spent AS customer_spent,
    (spm.total_tax_revenue - spm.total_supplycost) AS profit_margin
FROM 
    RankedSuppliers r
LEFT JOIN 
    HighValueCustomers c ON r.s_suppkey = c.c_custkey
LEFT JOIN 
    SupplierProfitMargins spm ON r.s_suppkey = spm.ps_partkey
WHERE 
    (c.total_spent IS NOT NULL OR r.order_count > 0) 
    AND ((spm.total_tax_revenue - spm.total_supplycost) IS NOT NULL OR (spm.total_tax_revenue - spm.total_supplycost) > 0)
ORDER BY 
    r.sales_rank, r.total_sales DESC;
