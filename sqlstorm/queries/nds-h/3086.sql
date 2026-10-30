WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerSpend AS (
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
HighSpenders AS (
    SELECT 
        cs.c_custkey
    FROM 
        CustomerSpend cs
    WHERE 
        cs.total_spent > (
            SELECT 
                AVG(total_spent) FROM CustomerSpend
        )
)
SELECT 
    p.p_name,
    p.p_brand,
    ra.o_orderdate,
    ra.total_revenue,
    sa.total_available,
    sa.unique_suppliers,
    CASE 
        WHEN ra.total_revenue IS NULL THEN 'No Orders' 
        ELSE 'Orders Found' 
    END AS order_status
FROM 
    part p
LEFT JOIN 
    SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN 
    RankedOrders ra ON ra.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN HighSpenders hs ON o.o_custkey = hs.c_custkey
    )
WHERE 
    p.p_container IS NOT NULL 
    AND (sa.unique_suppliers > 5 OR sa.total_available IS NULL)
ORDER BY 
    p.p_name, ra.total_revenue DESC
LIMIT 100;
