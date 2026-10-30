WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%widget%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    COALESCE(cd.c_name, 'No Orders') AS customer_name,
    COALESCE(cd.order_count, 0) AS order_count,
    COALESCE(cd.total_spent, 0) AS total_spent
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierDetails sd ON sd.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
LEFT JOIN 
    CustomerOrders cd ON cd.order_count > 5
WHERE 
    rp.rnk <= 5
ORDER BY 
    rp.p_retailprice DESC, sd.total_cost DESC;
