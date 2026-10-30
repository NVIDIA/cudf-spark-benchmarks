WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders AS o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer AS c
    LEFT JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    COALESCE(NULLIF(co.avg_order_value, 0), (SELECT AVG(total_spent) FROM CustomerOrderStats)) AS avg_order_value,
    su.s_name AS highest_cost_supplier,
    su.total_supplycost
FROM 
    CustomerOrderStats AS co
LEFT JOIN 
    (SELECT 
        sd.s_name, 
        sd.total_supplycost,
        RANK() OVER (ORDER BY sd.total_supplycost DESC) AS supplier_rank
     FROM 
        SupplierDetails AS sd
    ) AS su ON su.supplier_rank = 1
WHERE 
    co.order_count > 0
ORDER BY 
    co.total_spent DESC
LIMIT 10;