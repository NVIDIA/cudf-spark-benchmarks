WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        DENSE_RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown' 
            WHEN s.s_acctbal < 1000 THEN 'Low Balance' 
            ELSE 'High Balance' 
        END AS balance_category
    FROM 
        supplier s
),
PartAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availability,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        pa.total_availability,
        cs.total_orders,
        cs.total_spent,
        CASE 
            WHEN cs.total_spent > 10000 THEN 'VIP' 
            WHEN cs.total_orders > 5 THEN 'Frequent' 
            ELSE 'Occasional' 
        END AS customer_type
    FROM 
        part p
    LEFT JOIN 
        PartAvailability pa ON p.p_partkey = pa.ps_partkey
    LEFT JOIN 
        CustomerOrders cs ON cs.total_orders = (
            SELECT MAX(total_orders) 
            FROM CustomerOrders 
            WHERE total_spent IS NOT NULL
        )
    WHERE 
        p.p_retailprice BETWEEN 10 AND 500
)

SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_retailprice,
    fp.total_availability,
    fp.customer_type,
    rs.s_name AS top_supplier,
    rs.balance_category
FROM 
    FilteredParts fp
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1 AND rs.s_nationkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        WHERE n.n_nationkey = (
            SELECT c.c_nationkey 
            FROM customer c 
            WHERE c.c_custkey = (
                SELECT MIN(c.c_custkey) 
                FROM customer c 
                WHERE c.c_acctbal IS NOT NULL
            )
        )
    )
WHERE 
    (fp.total_availability IS NULL OR fp.total_availability > 100) 
    AND (fp.customer_type = 'VIP' OR fp.customer_type = 'Frequent')
ORDER BY 
    fp.p_retailprice DESC,
    fp.total_availability ASC
LIMIT 50;

