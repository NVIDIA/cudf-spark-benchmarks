WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        COUNT(DISTINCT ps.ps_partkey) AS num_parts, 
        RANK() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.supplier_rank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
SupplierPreferences AS (
    SELECT 
        c.c_custkey,
        s.s_suppkey,
        SUM(l.l_quantity * l.l_extendedprice) AS total_purchases
    FROM 
        CustomerOrders c
    JOIN 
        lineitem l ON c.c_custkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        c.c_custkey, s.s_suppkey
)
SELECT 
    c.c_name AS Customer_Name,
    s.s_name AS Supplier_Name,
    sp.total_purchases AS Total_Purchase_Amount
FROM 
    SupplierPreferences sp
JOIN 
    customer c ON sp.c_custkey = c.c_custkey
JOIN 
    supplier s ON sp.s_suppkey = s.s_suppkey
ORDER BY 
    c.c_name, s.s_name;
