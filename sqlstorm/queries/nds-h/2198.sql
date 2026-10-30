WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sale_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
), CustomerOrders AS (
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
)
SELECT 
    r.r_name,
    NS.total_sale,
    NS.sale_rank,
    CO.total_spent,
    CO.order_count,
    SSD.total_cost
FROM 
    RankedSales NS
JOIN 
    supplier S ON NS.p_partkey = S.s_suppkey
LEFT JOIN 
    SupplierDetails SSD ON S.s_nationkey = SSD.s_nationkey
JOIN 
    region r ON S.s_nationkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders CO ON S.s_suppkey = CO.c_custkey
WHERE 
    NS.sale_rank = 1 
    AND (CO.total_spent IS NULL OR CO.order_count > 5)
ORDER BY 
    r.r_name, NS.total_sale DESC;
