WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.s_acctbal,
        r.s_comment
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank <= 5
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    f.s_name AS supplier_name,
    f.s_acctbal AS supplier_balance,
    c.c_name AS customer_name,
    c.order_count AS total_orders,
    c.total_spent AS total_spending,
    CONCAT('Supplier: ', f.s_name, ' - Customer: ', c.c_name) AS combined_info
FROM 
    FilteredSuppliers f
JOIN 
    CustomerOrderStats c ON f.s_suppkey = c.c_custkey
WHERE 
    f.s_comment LIKE '%high priority%'
ORDER BY 
    f.s_acctbal DESC, c.total_spent DESC;
