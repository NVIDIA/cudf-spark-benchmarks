
WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'  
), 
SupplierPartSummary AS (
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
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
RegionSupplier AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.o_orderdate,
    co.o_totalprice,
    l.total_revenue,
    l.avg_quantity,
    ps.total_supply_cost,
    COALESCE(rs.supplier_count, 0) AS suppliers_in_region
FROM 
    CustomerOrders co
LEFT JOIN 
    LineItemSummary l ON co.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierPartSummary ps ON ps.s_suppkey IN (
        SELECT ps2.ps_suppkey 
        FROM partsupp ps2 
        WHERE ps2.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_size > 10 
              AND p.p_retailprice < 100.00
        )
    )
LEFT JOIN 
    RegionSupplier rs ON co.c_custkey IN (
        SELECT c2.c_custkey 
        FROM customer c2 
        WHERE c2.c_nationkey IN (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_regionkey = (
                SELECT r.r_regionkey 
                FROM region r 
                WHERE r.r_name = 'Asia'
            )
        )
    )
WHERE 
    co.order_rank = 1
ORDER BY 
    co.o_totalprice DESC
LIMIT 100; 
