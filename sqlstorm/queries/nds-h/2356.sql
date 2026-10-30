WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_orderkey) AS total_orders,
        MAX(l.l_extendedprice) AS max_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
FinalReport AS (
    SELECT 
        ps.p_name,
        ps.total_quantity,
        ps.total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        sd.s_name AS supplier_name,
        sd.average_supply_cost
    FROM 
        PartSummary ps
    JOIN 
        lineitem l ON ps.p_partkey = l.l_partkey
    LEFT JOIN 
        SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
    WHERE 
        ps.total_quantity > 100 AND ps.max_price > 50
    GROUP BY 
        ps.p_name, ps.total_quantity, ps.total_orders, sd.s_name, sd.average_supply_cost
)

SELECT 
    fr.p_name,
    fr.total_quantity,
    fr.total_orders,
    fr.net_revenue,
    fr.supplier_name,
    fr.average_supply_cost,
    CASE 
        WHEN fr.average_supply_cost IS NULL THEN 'No Supplier'
        ELSE 'Available Supplier'
    END AS supplier_status
FROM 
    FinalReport fr
WHERE 
    fr.net_revenue > 10000
ORDER BY 
    fr.net_revenue DESC
LIMIT 10;