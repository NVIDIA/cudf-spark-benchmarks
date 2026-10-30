WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 100.00
), 
AvailableParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 0
), 
CustomerOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_custkey
    HAVING 
        SUM(o.o_totalprice) > 500
), 
LowStockParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        CASE 
            WHEN COUNT(ps.ps_supplycost) = 0 THEN 'NOT SUPPLIED'
            ELSE 'LOW STOCK'
        END AS stock_status
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
    HAVING 
        COUNT(ps.ps_availqty) < 5
), 
OrdersWithSupplierInfo AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        s.s_name,
        CASE 
            WHEN l.l_discount > 0.30 THEN 'HIGH DISCOUNT'
            WHEN l.l_discount BETWEEN 0.20 AND 0.30 THEN 'MEDIUM DISCOUNT'
            ELSE 'LOW DISCOUNT'
        END AS discount_category
    FROM 
        lineitem l
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    WHERE 
        l.l_returnflag = 'N'
), 
FinalOutput AS (
    SELECT 
        co.o_custkey,
        SUM(lwi.l_quantity) AS total_quantity,
        SUM(lwi.l_extendedprice * (1 - lwi.l_discount)) AS total_revenue,
        n.n_name AS nation_name,
        rs.s_name AS top_supplier
    FROM 
        CustomerOrders co
    JOIN 
        lineitem lwi ON co.o_custkey = lwi.l_orderkey
    JOIN 
        supplier rs ON lwi.l_suppkey = rs.s_suppkey
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE 
        co.order_count > 1
    GROUP BY 
        co.o_custkey, n.n_name, rs.s_name
    ORDER BY 
        total_revenue DESC
)
SELECT 
    f.o_custkey,
    f.total_quantity,
    f.total_revenue,
    f.nation_name,
    COALESCE(f.top_supplier, 'UNKNOWN') AS top_supplier,
    CASE 
        WHEN f.total_revenue > 100000 THEN 'HIGH ROLLER'
        WHEN f.total_revenue BETWEEN 50000 AND 100000 THEN 'MEDIUM SPENDER'
        ELSE 'BUDGET CONSCIOUS'
    END AS spending_category
FROM 
    FinalOutput f
WHERE 
    f.total_quantity IS NOT NULL
AND 
    f.total_revenue >= (SELECT MAX(avg_supply_cost) FROM AvailableParts) 
ORDER BY 
    spending_category, total_revenue DESC;