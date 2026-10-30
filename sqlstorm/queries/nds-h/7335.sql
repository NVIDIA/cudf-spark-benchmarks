
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_avail_qty,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_brand
),
TopParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        rp.total_avail_qty
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_spent,
        ROW_NUMBER() OVER (ORDER BY co.total_spent DESC) AS rn
    FROM 
        CustomerOrders co
)
SELECT 
    pc.p_partkey, 
    pc.p_name, 
    pc.p_retailprice, 
    tc.c_custkey, 
    tc.c_name, 
    tc.total_spent
FROM 
    TopParts pc
JOIN 
    lineitem li ON li.l_partkey = pc.p_partkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    TopCustomers tc ON o.o_custkey = tc.c_custkey
WHERE 
    tc.rn <= 10
ORDER BY 
    pc.p_retailprice DESC, tc.total_spent DESC;
