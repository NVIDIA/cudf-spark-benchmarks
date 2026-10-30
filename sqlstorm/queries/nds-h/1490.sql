
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), HighSpenders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS spender_rank
    FROM 
        CustomerOrders co
    WHERE 
        co.total_spent > 1000
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps 
    INNER JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
)
SELECT 
    h.c_custkey,
    h.c_name,
    h.total_spent,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    sp.supplier_count,
    CASE 
        WHEN h.total_spent > 5000 THEN 'VIP'
        WHEN h.total_spent > 2000 THEN 'Regular'
        ELSE 'Occasional'
    END AS category 
FROM 
    HighSpenders h
LEFT JOIN 
    SupplierParts sp ON h.c_custkey = (
        SELECT 
            DISTINCT s.s_nationkey 
        FROM 
            supplier s 
        WHERE 
            s.s_suppkey = (
                SELECT 
                    ps.ps_suppkey 
                FROM 
                    partsupp ps 
                WHERE 
                    ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice < 50)
                LIMIT 1)
    )
WHERE 
    h.spender_rank <= 10
ORDER BY 
    h.total_spent DESC;
