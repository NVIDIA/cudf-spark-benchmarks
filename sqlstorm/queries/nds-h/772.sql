
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey 
    WHERE 
        ss.rank <= 10 OR ss.rank IS NULL
),
CustomerTotal AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    ts.s_name AS supplier_name,
    COUNT(DISTINCT ct.c_custkey) AS customer_count,
    SUM(ct.total_spent) AS total_customer_spent,
    ts.total_sales
FROM 
    TopSuppliers ts
LEFT JOIN 
    CustomerTotal ct ON ts.s_suppkey = ct.c_custkey
GROUP BY 
    ts.s_name, ts.total_sales
HAVING 
    SUM(ct.total_spent) > 50000
ORDER BY 
    ts.total_sales DESC;
