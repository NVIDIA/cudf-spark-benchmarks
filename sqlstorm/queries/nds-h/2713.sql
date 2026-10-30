
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierDetails AS (
    SELECT
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        rs.total_cost,
        hv.order_value
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
    LEFT JOIN 
        HighValueOrders hv ON s.s_nationkey = hv.o_custkey
    WHERE 
        rs.rank = 1
),
FinalResults AS (
    SELECT 
        region_name,
        nation_name,
        supplier_name,
        COALESCE(total_cost, 0) AS total_cost,
        COALESCE(order_value, 0) AS order_value,
        COALESCE(total_cost, 0) - COALESCE(order_value, 0) AS profit_loss
    FROM 
        SupplierDetails
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    total_cost,
    order_value,
    profit_loss
FROM 
    FinalResults
ORDER BY 
    region_name, nation_name, profit_loss DESC;
