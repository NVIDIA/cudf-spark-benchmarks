WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerTotalOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(ps.ps_availqty, 0) AS available_quantity,
        CASE 
            WHEN p.p_retailprice < 100 THEN 'Low Price'
            WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'Medium Price'
            ELSE 'High Price'
        END AS price_category
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
LatestOrderInfo AS (
    SELECT 
        o.o_orderkey,
        MAX(o.o_orderdate) AS max_order_date
    FROM 
        orders o 
    GROUP BY 
        o.o_orderkey
)
SELECT 
    cs.c_custkey,
    cs.total_spent AS customer_total_spent,
    ps.p_name AS product_name,
    ps.available_quantity,
    ps.price_category,
    RS.s_name AS supplier_name,
    RS.rnk AS supplier_rank
FROM 
    CustomerTotalOrders cs
LEFT JOIN 
    lineitem li ON cs.c_custkey = li.l_orderkey 
JOIN 
    PartDetails ps ON li.l_partkey = ps.p_partkey
JOIN 
    RankedSuppliers RS ON ps.available_quantity > 0 AND RS.rnk <= 5
WHERE 
    ps.price_category = 'High Price'
    AND cs.total_spent > (SELECT AVG(total_spent) FROM CustomerTotalOrders)
    AND EXISTS (SELECT 1 FROM LatestOrderInfo lo WHERE lo.o_orderkey = li.l_orderkey AND lo.max_order_date < cast('1998-10-01' as date) - INTERVAL '30 days')
ORDER BY 
    cs.total_spent DESC, 
    ps.p_retailprice ASC, 
    RS.s_name;