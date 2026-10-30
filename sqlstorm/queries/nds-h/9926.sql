WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
TopCustomers AS (
    SELECT 
        ra.c_name,
        COUNT(ra.o_orderkey) AS order_count,
        SUM(ra.o_totalprice) AS total_spent
    FROM 
        RankedOrders ra
    WHERE 
        ra.order_rank <= 5
    GROUP BY 
        ra.c_name
    ORDER BY 
        total_spent DESC
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
),
FinalOutput AS (
    SELECT
        tc.c_name,
        tc.order_count,
        tc.total_spent,
        sd.s_name AS supplier_name,
        sd.total_supply_cost
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SupplierDetails sd ON tc.c_name = sd.s_name
)
SELECT 
    fo.c_name,
    fo.order_count,
    fo.total_spent,
    fo.supplier_name,
    COALESCE(fo.total_supply_cost, 0) AS total_supply_cost
FROM 
    FinalOutput fo
ORDER BY 
    fo.total_spent DESC, 
    fo.order_count DESC;