WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT 
                AVG(ps_supplycost) 
            FROM 
                partsupp 
            WHERE 
                ps_availqty > 0
        )
), SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    DISTINCT p.p_name, 
    p.p_brand, 
    si.s_name AS supplier_name,
    CASE 
        WHEN co.order_count IS NULL THEN 'No Orders'
        ELSE CONCAT(co.order_count, ' Orders - Total: $', co.total_spent)
    END AS customer_order_summary
FROM 
    RankedParts p
LEFT JOIN 
    SupplierInfo si ON si.total_supply_value > (
        SELECT 
            AVG(total_supply_value) 
        FROM 
            SupplierInfo
    )
LEFT JOIN 
    CustomerOrders co ON si.s_nationkey = co.c_custkey 
WHERE 
    p.rank <= 10 
    AND p.p_retailprice < (
        SELECT 
            MAX(p2.p_retailprice) 
            FROM 
                part p2 
            WHERE 
                p2.p_size = 15
    )
ORDER BY 
    p.p_brand, p.p_name;
