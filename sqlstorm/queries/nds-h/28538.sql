WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUBSTRING(s.s_comment, 1, 30) AS short_comment,
        NTILE(5) OVER (ORDER BY s.s_acctbal DESC) AS balance_rank
    FROM 
        supplier s
),
PartInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        CONCAT(p.p_brand, ' ', p.p_type, ' ', CAST(p.p_size AS STRING)) AS full_description
    FROM 
        part p
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        o.o_orderkey, 
        o.o_orderdate,
        COUNT(li.l_orderkey) AS item_count,
        SUM(li.l_extendedprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    r.s_name,
    pi.full_description,
    COUNT(co.o_orderkey) AS total_orders,
    SUM(co.total_spent) AS total_revenue,
    r.balance_rank
FROM 
    RankedSuppliers r
JOIN 
    PartInfo pi ON r.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_name LIKE '%screws%'
            LIMIT 1
        )
        LIMIT 1
    )
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_totalprice > 1000 
        LIMIT 1
    )
GROUP BY 
    r.s_suppkey, r.s_name, pi.full_description, r.balance_rank
ORDER BY 
    total_revenue DESC, r.s_name ASC;
