WITH SupplierPartCost AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        (ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
),
RankedSuppliers AS (
    SELECT
        spc.s_suppkey,
        spc.s_name,
        SUM(spc.total_cost) AS supplier_total_cost,
        RANK() OVER (ORDER BY SUM(spc.total_cost) DESC) AS supplier_rank
    FROM SupplierPartCost spc
    GROUP BY spc.s_suppkey, spc.s_name
),
TopCustomers AS (
    SELECT
        cus.c_custkey,
        cus.c_name,
        cus.total_order_value,
        cus.order_count,
        RANK() OVER (ORDER BY cus.total_order_value DESC) AS customer_rank
    FROM CustomerOrderSummary cus
)
SELECT 
    tc.c_name AS top_customer,
    tc.total_order_value AS customer_value,
    ts.s_name AS top_supplier,
    ts.supplier_total_cost AS supplier_cost
FROM TopCustomers tc
JOIN RankedSuppliers ts ON tc.order_count > 0
WHERE tc.customer_rank <= 10 AND ts.supplier_rank <= 10
ORDER BY tc.total_order_value DESC, ts.supplier_total_cost DESC;
