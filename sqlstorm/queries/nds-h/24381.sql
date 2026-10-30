WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
CustomerStats AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 0
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    ps.total_avail,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 1000 THEN 'High Spender'
        ELSE 'Regular Customer'
    END AS customer_segment,
    RANK() OVER (ORDER BY p.p_retailprice) AS price_rank
FROM 
    RankedParts p
LEFT JOIN 
    SupplierAvailability ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    CustomerStats cs ON cs.c_custkey = (
        SELECT 
            c.c_custkey
        FROM 
            customer c
        JOIN 
            orders o ON c.c_custkey = o.o_custkey
        WHERE 
            o.o_orderstatus = 'O'
        AND 
            EXISTS (
                SELECT 1
                FROM lineitem l
                WHERE l.l_orderkey = o.o_orderkey AND l.l_returnflag = 'N'
            )
        ORDER BY 
            o.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    p.rnk = 1
ORDER BY 
    p.p_partkey;
