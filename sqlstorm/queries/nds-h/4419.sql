WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT 
        c.*, 
        CASE 
            WHEN total_spent > 10000 THEN 'High'
            WHEN total_spent BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END AS spending_category
    FROM 
        CustomerOrders c
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    rs.s_name AS supplier_name,
    hsc.spending_category,
    n.n_name AS nation_name
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rnk <= 5
INNER JOIN 
    customer c ON c.c_custkey = l.l_orderkey
INNER JOIN 
    HighSpendingCustomers hsc ON c.c_custkey = hsc.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate <= DATE '1997-12-31'
GROUP BY 
    p.p_name, rs.s_name, hsc.spending_category, n.n_name
HAVING 
    SUM(l.l_quantity) > 0
ORDER BY 
    total_sales DESC, p.p_name ASC;