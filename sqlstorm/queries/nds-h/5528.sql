WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_availqty, 
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
AggregatedData AS (
    SELECT 
        sp.s_suppkey, 
        sp.s_name, 
        SUM(od.l_quantity) AS total_quantity, 
        SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue
    FROM 
        SupplierParts sp
    JOIN 
        OrderDetails od ON sp.p_partkey = od.l_partkey
    GROUP BY 
        sp.s_suppkey, sp.s_name
)
SELECT 
    ad.s_suppkey, 
    ad.s_name, 
    ad.total_quantity, 
    ad.total_revenue,
    RANK() OVER (ORDER BY ad.total_revenue DESC) AS revenue_rank
FROM 
    AggregatedData ad
WHERE 
    ad.total_quantity > 100
ORDER BY 
    revenue_rank
LIMIT 10;