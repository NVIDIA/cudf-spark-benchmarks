WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate ASC) AS priority_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_address, ''), 'No Address') AS s_address,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(*) AS item_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.05 AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    sd.s_name,
    sd.s_address,
    lis.net_revenue,
    lis.item_count,
    lis.avg_quantity,
    CASE 
        WHEN ro.order_rank <= 10 THEN 'Top Orders'
        ELSE 'Regular Orders'
    END AS order_category
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemSummary lis ON ro.o_orderkey = lis.l_orderkey
INNER JOIN 
    supplier s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_type LIKE '%widget%'
        )
    )
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
WHERE 
    ro.o_totalprice > (
        SELECT AVG(o.o_totalprice)
        FROM orders o 
        WHERE o.o_orderdate >= '1997-01-01'
    )
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;