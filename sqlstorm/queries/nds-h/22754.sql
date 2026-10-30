WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_spent 
    FROM 
        CustomerOrderInfo c 
    WHERE 
        total_spent > (SELECT AVG(total_spent) FROM CustomerOrderInfo)
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    p.p_retailprice,
    r.r_name AS region_name,
    CASE 
        WHEN c.c_custkey IS NOT NULL THEN 'Customer Exists' 
        ELSE 'No Customer' 
    END AS customer_existence,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank,
    (SELECT SUM(l.l_quantity) 
     FROM lineitem l 
     WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'N') AS total_quantity_sold
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueCustomers c ON c.c_custkey = s.s_suppkey
WHERE 
    p.p_retailprice BETWEEN 100.00 AND 1000.00
    AND (s.s_acctbal IS NULL OR s.s_acctbal >= 500.00)
    AND (p.p_name LIKE '%part%' OR p.p_comment IS NOT NULL)
ORDER BY 
    p.p_partkey, price_rank DESC
LIMIT 50;
