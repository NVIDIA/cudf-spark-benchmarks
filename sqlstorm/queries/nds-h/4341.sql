
WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    INNER JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
          AND o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
LineitemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(*) AS lineitem_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    co.c_name,
    co.o_orderkey,
    COALESCE(ld.revenue, 0) AS revenue,
    COALESCE(sc.total_supply_cost, 0) AS supplier_cost,
    CASE 
        WHEN COALESCE(ld.lineitem_count, 0) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS order_status,
    DENSE_RANK() OVER (PARTITION BY co.c_custkey ORDER BY COALESCE(ld.revenue, 0) DESC) AS revenue_rank
FROM 
    CustomerOrders co
LEFT JOIN 
    LineitemDetails ld ON co.o_orderkey = ld.l_orderkey
LEFT JOIN 
    SupplierCost sc ON sc.s_suppkey IN (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey 
        WHERE 
            p.p_brand = 'Brand#10'
    )
WHERE 
    co.o_totalprice > 1000
ORDER BY 
    co.c_name, COALESCE(ld.revenue, 0) DESC;
